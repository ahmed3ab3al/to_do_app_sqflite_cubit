import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:to_do_project/shared/cubit/states.dart';
import '../../modules/archived_tasks/archived_tasks_screen.dart';
import '../../modules/done_tasks/done_tasks_screen.dart';
import '../../modules/new_tasks/new_tasks_screen.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitialState());

  static AppCubit get(context) => BlocProvider.of(context);

  List<Widget> screens = [
    const NewTasksScreen(),
    const DoneTasksScreen(),
    const ArchivedTasksScreen()
  ];

  List<String> titles = [
    'New Tasks',
    'Done Tasks',
    'Archived Tasks',
  ];

  int currentIndex = 0;

  void changeIndex(int index) {
    currentIndex = index;
    emit(AppChangeBottomNavBarState());
  }

  List<Map> newTasks = [];
  List<Map> doneTasks = [];
  List<Map> archivedTasks = [];
  IconData fabIcon = Icons.edit;

  bool isBottomSheetShown = false;

  Database? database;

  void createDatabase() {
    openDatabase('todo.db', version: 1, onCreate: (database, version) {
      database
          .execute(
          'CREATE TABLE tasks (id INTEGER PRIMARY KEY,title TEXT,data TEXT,time TEXT, status TEXT)')
          .then((value) {
        // ignore: avoid_print
        print("Database Created");
      }).catchError((error) {
        // ignore: avoid_print
        print("Error while creating database ${error.toString()}");
      });
    }, onOpen: (database) {
      getDataFromDatabase(database);
      // ignore: avoid_print
      print("Database opened");
    }).then((value) {
      database = value;
      emit(AppCreateDataBaseState());
    });
  }

  insertDatabase({
    required String title,
    required String time,
    required String data,
  }) async {
    await database?.transaction((txn) =>
        txn
            .rawInsert(
            'INSERT INTO tasks(title,data,time,status) VALUES("$title","$data","$time","new")')
            .then((value) {
          // ignore: avoid_print
          print(" $value inserted successfully");
          emit(AppInsertDataBaseState());
          getDataFromDatabase(database);
        }).catchError((error) {
          // ignore: avoid_print
          print("error when inserting new record${error.toString()}");
        }));
  }

  void getDataFromDatabase(database) {
    newTasks = [];
    doneTasks = [];
    archivedTasks = [];
    emit(AppGetDataBaseLoadingState());
    database!.rawQuery('SELECT * FROM tasks').then((value) {
      value.forEach((element) {
        if (element['status'] == 'new') {
          newTasks.add(element);
        } else if (element['status'] == 'done') {
          doneTasks.add(element);
        }
        else {
          archivedTasks.add(element);
        }
      });
      emit(AppGetDataBaseState());
    });
  }

  void upDateDataBase({
    required String status,
    required int id,
  }) async {
    database?.rawUpdate('UPDATE tasks SET status = ?  WHERE id = ?',
        [status, id]).then((value) {
      getDataFromDatabase(database);
      emit(AppUpDateDataBaseState());
    });
  }

  void deleteDataBase({
    required int id,
  }) async {
    database?.rawDelete('DELETE FROM tasks WHERE id = ?', [id])
        .then((value) {
      getDataFromDatabase(database);
      emit(AppDeleteDataBaseState());
    });
  }

  void changeButtonSheetState({
    required IconData icon,
    required bool isShow,
  }) {
    isBottomSheetShown = isShow;
    fabIcon = icon;
    emit(AppChangeButtomSheetState());
  }
}