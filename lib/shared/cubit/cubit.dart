import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import '../../modules/archived_tasks/archived_tasks.dart';
import '../../modules/done_tasks/done_tasks.dart';
import '../../modules/new_tasks/new_tasks.dart';
import 'states.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitialState());

  static AppCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;

  List<Widget> screens = [
    NewTasksScreen(),
    DoneTasksScreen(),
    ArchivedTasksScreen()
  ];

  List<String> titles = ['New Tasks', 'Done Tasks', 'Archived Tasks'];

  void changeIndex(int index) {
    currentIndex = index;
    emit(AppChangeBottomNavBarState());
  }

  Database? database;

  List<Map> newTasks = [];
  List<Map> archivedTasks = [];
  List<Map> doneTasks = [];

  void createDatabase() {
    openDatabase(
      'todo.db',
      version: 1,
      onCreate: (database, version) {
        print('Data Base Created');
        database
            .execute(
                'CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT, date TEXT, time TEXT, status TEXT)')
            .then((value) {
          print('table created');
        }).catchError((error) {
          print('Error When Creating Table ${error.toString()}');
        });
      },
      onOpen: (database) {
        getDataFromDatabase(database);
        print('Data Base Opened');
      },
    ).then((value) {
      database = value;
      emit(AppCreateDatbaseState());
    });
  }

  insertToDatabase({
    required String title,
    required String time,
    required String date,
  }) async {
    await database?.transaction(
      (txn) {
        return txn
            .rawInsert(
                'INSERT INTO tasks(title, date, time, status) VALUES("$title", "$date", "$time", "new")')
            .then((value) {
          print('$value inserted successfuly');
          emit(AppInsertDatbaseState());
          getDataFromDatabase(database!);
        }).catchError((error) {
          print('Error When Inserting New Record ${error.toString()}');
        });
      },
    );
  }

  void getDataFromDatabase(Database? database) {
    newTasks = [];
    doneTasks = [];
    archivedTasks = [];
    emit(AppGetDatbasLoadingeState());
    database!.rawQuery('SELECT * FROM tasks').then((value) {
      newTasks = value;
      print(newTasks);
      value.forEach((element) {
        if (element['status'] == 'new') {
          newTasks.add(element);
        } else if (element['status'] == 'done') {
          doneTasks.add(element);
        } else {
          archivedTasks.add(element);
        }
      });
      emit(AppGetDatbaseState());
    });
  }

  void updateData({required String? status, required int? id}) async {
    await database!.rawUpdate(
      'UPDATE tasks SET status = ? WHERE id = ?',
      ['$status', '$id'],
    ).then((value) {
      getDataFromDatabase(database);
      emit(AppUpdateDatbaseState());
    });
  }

  bool isBottomSheetShown = false;

  IconData faBIcon = Icons.edit;

  void changeBottomSheetState({required bool isShow, required IconData icon}) {
    isBottomSheetShown = isShow;
    faBIcon = icon;
    emit(AppChangeBottomSheetState());
  }
}
