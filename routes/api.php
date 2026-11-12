<?php

use App\Http\Controllers\Api\AbastecimentoController;
use App\Http\Controllers\Api\DespesaController;
use App\Http\Controllers\Api\ManutencaoController;
use App\Http\Controllers\Api\MotoristaController;
use App\Http\Controllers\Api\VeiculoController;
use App\Http\Controllers\Api\ViagemController;
use Illuminate\Support\Facades\Route;

Route::name('api.')->group(function (): void {
    Route::apiResource('veiculos', VeiculoController::class);
    Route::apiResource('motoristas', MotoristaController::class);
    Route::apiResource('abastecimentos', AbastecimentoController::class);
    Route::apiResource('despesas', DespesaController::class);
    Route::apiResource('viagens', ViagemController::class)->only(['index', 'show', 'store']);
    Route::post('/viagens/{id}/finalizar', [ViagemController::class, 'finalizar'])
        ->name('viagens.finalizar');
    Route::apiResource('manutencoes', ManutencaoController::class)->only(['index', 'show', 'store']);
    Route::post('/manutencoes/{id}/concluir', [ManutencaoController::class, 'concluir'])
        ->name('manutencoes.concluir');
});
