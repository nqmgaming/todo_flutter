import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:todo_list/futures/todo_list/domain/entities/todo.dart';
import 'package:todo_list/futures/todo_list/domain/usecases/delete_todo.dart';
import 'package:todo_list/futures/todo_list/domain/usecases/get_all_todos.dart';
import 'package:todo_list/futures/todo_list/domain/usecases/insert_todo.dart';
import 'package:todo_list/futures/todo_list/domain/usecases/update_todo.dart';
import '../../../../core/usecases/usecase.dart';

part 'todo_event.dart';

part 'todo_state.dart';

@injectable
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final GetAllTodos getAllTodos;
  final InsertTodo insertTodo;
  final DeleteTodo deleteTodo;
  final UpdateTodo updateTodo;

  TodoBloc({
    required this.getAllTodos,
    required this.insertTodo,
    required this.deleteTodo,
    required this.updateTodo,
  }) : super(TodoInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<AddTodoEvent>(_onAddTodo);
    on<DeleteTodoEvent>(_onDeleteTodo);
    on<UpdateTodoEvent>(_onUpdateTodo);
  }

  Future<void> _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    emit(TodoLoading());
    final todosOrFailure = await getAllTodos(NoParams());
    todosOrFailure.fold(
      (failure) => emit(TodoError(message: failure.message)),
      (todos) => emit(TodoLoaded(todos: todos)),
    );
  }

  Future<void> _onAddTodo(AddTodoEvent event, Emitter<TodoState> emit) async {
    final todoOrFailure = await insertTodo(event.todo);
    todoOrFailure.fold(
      (failure) => emit(TodoError()),
      (todo) async {
        if (state is TodoLoaded) {
          final List<Todo> updatedTodos = List.from((state as TodoLoaded).todos)
            ..add(todo);
          emit(TodoLoaded(todos: updatedTodos));
        } else {
          emit(TodoLoaded(todos: [todo]));
        }
      },
    );
  }

  Future<void> _onDeleteTodo(
      DeleteTodoEvent event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final List<Todo> updatedTodos = List.from((state as TodoLoaded).todos)
        ..remove(event.todo);
      final todoOrFailure = await deleteTodo(event.todo);
      todoOrFailure.fold(
        (failure) => emit(TodoError()),
        (_) => emit(TodoLoaded(todos: updatedTodos)),
      );
      emit(TodoLoaded(todos: updatedTodos));
    }
  }

  Future<void> _onUpdateTodo(
      UpdateTodoEvent event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final List<Todo> updatedTodos = List.from((state as TodoLoaded).todos)
        ..removeWhere((todo) => todo.id == event.todo.id)
        ..add(event.todo);
      final todoOrFailure = await updateTodo(event.todo);
      todoOrFailure.fold(
        (failure) => emit(TodoError()),
        (_) => emit(TodoLoaded(todos: updatedTodos)),
      );
      emit(TodoLoaded(todos: updatedTodos));
    }
  }
}
