<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});

Route::get('/ping', function () {
    return 'pong';
});

Route::get('/hello', function () {
    return response()->json([
        'hello' => 'world',
    ]);
});

Route::get('/user/{name?}', function ($name = null){
    if (is_null($name)) {
        $name = false;
    }

    return response()->json([
        'name' => $name,
    ]);
});