import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_player/src/bloc/audio_bloc.dart';
import 'package:m_player/src/views/home_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      
      create: (_) => AudioBloc(AudioPlayer())..add(LoadAudio()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mp3 Player',
        theme: ThemeData(
          // tested with just a hot reload.
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: HomeView(),
        
      ),
    );
  }
}
