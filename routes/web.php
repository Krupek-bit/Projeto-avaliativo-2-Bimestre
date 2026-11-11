<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ViagemController;

Route::get('/', function () {
    return view('welcome');
});

// Rotas de viagens
Route::get('/viagens', [ViagemController::class, 'index'])
    ->name('viagens.index');

Route::get('/viagens/criar', [ViagemController::class, 'create'])
    ->name('viagens.create');

Route::post('/viagens', [ViagemController::class, 'store'])
    ->name('viagens.store');

Route::get('/viagens/{id}', [ViagemController::class, 'show'])
    ->name('viagens.show');

Route::post('/viagens/{id}/finalizar', [ViagemController::class, 'finalizar'])
    ->name('viagens.finalizar');
