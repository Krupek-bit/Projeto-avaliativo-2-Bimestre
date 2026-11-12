<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreHodometroRequest;
use App\Services\HodometroService;
use App\Services\VeiculoService;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

class HodometroController extends Controller
{
    public function __construct(
        private HodometroService $hodometroService,
        private VeiculoService $veiculoService,
    ) {}

    public function index(): View
    {
        $hodometros = $this->hodometroService->listar();

        return view('hodometros.index', compact('hodometros'));
    }

    public function create(): View
    {
        $veiculos = $this->veiculoService->listar();

        return view('hodometros.create', compact('veiculos'));
    }

    public function store(StoreHodometroRequest $request): RedirectResponse
    {
        $this->hodometroService->registrar($request->validated());

        return redirect()
            ->route('hodometros.index')
            ->with('success', 'Quilometragem registrada com sucesso!');
    }
}
