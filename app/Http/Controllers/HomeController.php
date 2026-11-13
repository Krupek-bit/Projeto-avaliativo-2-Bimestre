<?php

namespace App\Http\Controllers;

use App\Models\Motorista;
use App\Models\Veiculo;
use App\Models\Viagem;

class HomeController extends Controller
{
    public function index()
    {
        return view('home', [
            'veiculosAtivos' => Veiculo::where('status', 'ativo')->count(),
            'veiculosEmViagem' => Veiculo::where('status', 'em_viagem')->count(),
            'motoristas' => Motorista::count(),
            'viagensAndamento' => Viagem::whereNull('data_retorno')->count(),
        ]);
    }
}