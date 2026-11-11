<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\VeiculoController;

Route::apiResource('veiculos', VeiculoController::class);

