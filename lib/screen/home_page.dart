import 'dart:async';
import 'dart:io';

import 'package:api_caching/bloc/bloc.dart';
import 'package:api_caching/model/pokemon.dart';
import 'package:api_caching/model/results.dart';
import 'package:api_caching/singleton/hive_singleton.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Bloc _bloc = Bloc();

  @override
  void initState() {
    super.initState();
    InternetConnectionChecker().onStatusChange.listen(
      (event) async {
        await shouldOrShouldNotMakeAnAPICall();
      },
    );
  }

  @override
  void dispose() {
    _bloc.loadingBehaviour.close();
    HiveSingleton().pokemonBox.close();
    HiveSingleton().resultsBox.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("API records Caching"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: showModalBottomSheet,
              icon: const Icon(
                Icons.info_outline,
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: _bloc.loadingBehaviour.stream,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            return (_bloc.loadingBehaviour.value == true)
                ? loadingIndicatorWidget()
                : valueListenableBuilderWidget();
          },
        ),
      ),
    );
  }

  Widget loadingIndicatorWidget() {
    return Center(
      child: Platform.isIOS
          ? const CupertinoActivityIndicator()
          : const CircularProgressIndicator(),
    );
  }

  Widget valueListenableBuilderWidget() {
    return ValueListenableBuilder<Box<Pokemon>>(
      valueListenable: HiveSingleton().pokemonBox.listenable(),
      builder: (BuildContext context, Box<Pokemon> value, Widget? child) {
        List<Pokemon> finalObject = value.values.toList().cast<Pokemon>();
        Pokemon pokemon = finalObject.isEmpty ? Pokemon() : finalObject.first;
        return (pokemon.results?.isEmpty ?? false)
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Data list is empty"),
                    const SizedBox(height: 50),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      onPressed: () async {
                        await shouldOrShouldNotMakeAnAPICall();
                      },
                      label: const Text("Try to fetch data from server"),
                    )
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await shouldOrShouldNotMakeAnAPICall();
                },
                child: ListView.builder(
                  itemCount: (pokemon.results?.length ?? 0),
                  itemBuilder: (BuildContext context, int index) {
                    Results results = (pokemon.results?[index] ?? Results());
                    return Card(
                      child: ListTile(
                        title: Text(results.name ?? ""),
                        trailing: IconButton(
                          onPressed: () async {
                            pokemon.results?.remove(results);
                            await pokemon.save();
                            return;
                          },
                          icon: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).iconTheme.color,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Theme.of(context).scaffoldBackgroundColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
      },
    );
  }

  Widget showBarModalBottomSheetWidget() {
    return SingleChildScrollView(
      controller: ModalScrollController.of(context),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Text(
              "About this app",
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "So, this application fetches data from the server and stores those data locally on our device. So, you can view the records even when you don't have an active internet connection. It is a kind of API records caching.",
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              "Firstly, the app will constantly be looking for internet connection changes.",
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              "If the app finds well-established internet, it will request the server for the latest updates. If the server provides positive responses, the app will remove all old stored records and store the latest fetched records.",
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              "Else if the app does not have well-established internet, it will show an appropriate message & the app will show the pre-fetched stored records.",
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> shouldOrShouldNotMakeAnAPICall() async {
    bool result = await InternetConnectionChecker().hasConnection;
    (result == true)
        ? await makeAnAPICall()
        : await Fluttertoast.showToast(msg: "Unable to fetch data from server");
    return Future.value();
  }

  Future<void> makeAnAPICall() async {
    _bloc.loadingFunction(true);
    Response response = await Dio().get("https://pokeapi.co/api/v2/pokemon/");
    if (response.statusCode == 200) {
      Pokemon pokemonObject = Pokemon.fromJson(response.data);
      await HiveSingleton().pokemonBox.clear();
      await HiveSingleton().pokemonBox.add(pokemonObject);
      await pokemonObject.save();
      await Fluttertoast.showToast(msg: "Fetched data from server");
    } else {
      await Fluttertoast.showToast(msg: "Status code: ${response.statusCode}");
    }
    _bloc.loadingFunction(false);
    return Future.value();
  }

  Future<void> showModalBottomSheet() {
    Future<void> value = showBarModalBottomSheet(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      context: context,
      builder: (BuildContext context) {
        return showBarModalBottomSheetWidget();
      },
    );
    return Future.value(value);
  }
}
