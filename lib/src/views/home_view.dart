import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:m_player/src/bloc/audio_bloc.dart';
import 'package:m_player/src/data/get_data.dart';
import 'package:m_player/src/widgets/audio_visualizer_custom_paint.dart';
import 'package:path_provider/path_provider.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AudioBloc, AudioState>(
        builder: (context, state) {
          if (state is AudioLoading) {
            return const Center(child: Text("Please wait ...."));
          } else if (state is AudioLoaded) {
            var size = MediaQuery.of(context).size;

            return Center(
              child: Container(
                height: 140,
                width: size.width - 30,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            context.read<AudioBloc>().add(PlayPauseAudio()),
                        icon: Icon(
                          state.playerState == PlayerState.playing
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      Stack(
                        children: [
                          Center(
                            child: Container(
                              height: 80,
                              width: size.width - 100,
                              child: CustomPaint(
                                isComplex: true,
                                painter: AudioWaveformPainter(
                                  duration: state.waveform.duration,
                                  start: Duration.zero,
                                  waveColor: Colors.white,
                                  waveform: state.waveform,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: AnimatedContainer(
                              duration: const Duration(seconds: 1),
                              height: 100,
                              width: size.width *
                                  5.8 *
                                  (state.position.inMilliseconds / 100000),
                              color: Colors.blue.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const Center(child: Text("Unknown state"));
          }
        },
      ),
    );
  }
}
