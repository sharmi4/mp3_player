import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:m_player/src/data/get_data.dart';
import 'package:path_provider/path_provider.dart';

// Events
abstract class AudioEvent extends Equatable {
  const AudioEvent();

  @override
  List<Object> get props => [];
}

class LoadAudio extends AudioEvent {}

class ResetAudio extends AudioEvent {}

class PlayPauseAudio extends AudioEvent {}

class UpdatePlayer extends AudioEvent {}

class UpdatePosition extends AudioEvent {
  final Duration position;

  const UpdatePosition(this.position);

  @override
  List<Object> get props => [position];
}

// States
abstract class AudioState extends Equatable {
  const AudioState();

  @override
  List<Object> get props => [];
}

class AudioInitial extends AudioState {}

class AudioLoading extends AudioState {}

class AudioLoaded extends AudioState {
  final Waveform waveform;
  final PlayerState playerState;
  final Duration position;

  const AudioLoaded({
    required this.waveform,
    this.playerState = PlayerState.paused,
    this.position = Duration.zero,
  });

  AudioLoaded copyWith({
    Waveform? waveform,
    PlayerState? playerState,
    Duration? position,
  }) {
    return AudioLoaded(
      waveform: waveform ?? this.waveform,
      playerState: playerState ?? this.playerState,
      position: position ?? this.position,
    );
  }

  @override
  List<Object> get props => [waveform, playerState, position];
}

// BLoC
class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final AudioPlayer player;
  Waveform? waveform;
  String? audioFilePath;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  AudioBloc(this.player) : super(AudioInitial()) {
    on<LoadAudio>(_onLoadAudio);
    on<ResetAudio>(_resetPlayer);
    on<PlayPauseAudio>(_onPlayPauseAudio);
    on<UpdatePlayer>(_onUpdatePlayerState);
    on<UpdatePosition>(_onUpdatePosition);
  }

  Future<void> _onLoadAudio(LoadAudio event, Emitter<AudioState> emit) async {
    if (state is AudioLoaded) return; // Prevent loading again if already loaded

    emit(AudioLoading());

    String filePath = await getData(); // Fetch the file path
    audioFilePath =  filePath;
    // Load waveform data
    await _loadWaveform(filePath);

    // Set up player
    await player.setSource(DeviceFileSource(filePath));

    // Initialize position and state listeners
    await _initPlayerListeners(emit);

    // Emit the loaded state
    emit(AudioLoaded(
      waveform: waveform!,
      playerState: player.state,
      position: Duration.zero,
    ));
  }


    Future<void> _resetPlayer(ResetAudio event, Emitter<AudioState> emit) async {
   
    await _loadWaveform(audioFilePath!);

    // Set up player
    await player.setSource(DeviceFileSource(audioFilePath!));

    // Initialize position and state listeners
    await _initPlayerListeners(emit);

    // Emit the loaded state
    emit(AudioLoaded(
      waveform: waveform!,
      playerState: player.state,
      position: Duration.zero,
    ));
  }


  Future<void> _onPlayPauseAudio(
      PlayPauseAudio event, Emitter<AudioState> emit) async {
    final currentState = state;
    print(state);
    if (currentState is AudioLoaded) {
      if (currentState.playerState == PlayerState.playing) {
        await player.pause();    
        emit(currentState.copyWith(playerState: PlayerState.paused));
      } else {
        print("Start PLaying----------->>");
        try {
          await player.resume();
        } catch (e) {
          // TODO
          print("Error occured $e");
        }
        emit(currentState.copyWith(playerState: PlayerState.playing));
      }
    }
  }

  Future<void> _onUpdatePlayerState(
      UpdatePlayer event, Emitter<AudioState> emit) async {
    final currentState = state;
    print(state);
    if (currentState is AudioLoaded) {
      if (currentState.playerState == PlayerState.playing) {
        emit(currentState.copyWith(playerState: PlayerState.paused));
        print("Wave form is ${waveform == null ? "null" : "Data is hete"}");
        // player.dispose();
        // emit(AudioLoaded(
        //   waveform: waveform!,
        //   playerState: PlayerState.stopped,
        //   position: Duration.zero,
        // ));
      } else {
        emit(currentState.copyWith(playerState: PlayerState.playing));
      }
    }
  }

  Future<void> _onUpdatePosition(
      UpdatePosition event, Emitter<AudioState> emit) async {
    final currentState = state;
    if (currentState is AudioLoaded) {
      emit(currentState.copyWith(position: event.position));
    }
  }

  Future<void> _loadWaveform(String path) async {
    final tempDir = await getTemporaryDirectory();
    File file = await File('${tempDir.path}/waveform.wave').create();
    final progressStream = JustWaveform.extract(
      audioInFile: File(path),
      waveOutFile: file,
      zoom: const WaveformZoom.pixelsPerSecond(100),
    );

    await for (final waveformProgress in progressStream) {
      if (waveformProgress.waveform != null) {
        waveform = waveformProgress.waveform;
        break;
      }
    }
  }

  Future<void> _initPlayerListeners(Emitter<AudioState> emit) async {
    // Cancel existing subscriptions to avoid multiple listeners
    await _positionSubscription?.cancel();
    await _playerStateChangeSubscription?.cancel();

    _positionSubscription = player.onPositionChanged.listen((position) {
      add(UpdatePosition(position));
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((playerState) async {
      if (playerState == PlayerState.completed) {
        add(const UpdatePosition(Duration.zero));
        await Future.delayed(const Duration(milliseconds: 500));
        add(UpdatePlayer());
        add(ResetAudio());
      } else {
        if (!emit.isDone) {
          emit((state as AudioLoaded).copyWith(playerState: playerState));
        }
      }
    });
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    player.dispose();
    return super.close();
  }
}
