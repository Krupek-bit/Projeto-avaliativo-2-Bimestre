<?php

use App\Http\Controllers\AbastecimentoController;
use App\Http\Controllers\DespesaController;
use App\Http\Controllers\HodometroController;
use App\Http\Controllers\ManutencaoController;
use App\Http\Controllers\MotoristaController;
use App\Http\Controllers\VeiculoController;
use App\Http\Controllers\ViagemController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::resource('veiculos', VeiculoController::class);
Route::resource('motoristas', MotoristaController::class);
Route::resource('abastecimentos', AbastecimentoController::class)
    ->except('show');
Route::resource('despesas', DespesaController::class)
    ->except('show');
Route::resource('manutencoes', ManutencaoController::class)
    ->only(['index', 'create', 'store']);
Route::resource('hodometros', HodometroController::class)
    ->only(['index', 'create', 'store']);
Route::post('/manutencoes/{id}/concluir', [ManutencaoController::class, 'concluir'])
    ->name('manutencoes.concluir');

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
