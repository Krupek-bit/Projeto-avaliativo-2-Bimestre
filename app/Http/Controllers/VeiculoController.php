<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreVeiculoRequest;
use App\Http\Requests\UpdateVeiculoRequest;
use App\Services\VeiculoService;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

class VeiculoController extends Controller
{
    protected VeiculoService $veiculoService;

    public function __construct(VeiculoService $veiculoService)
    {
        $this->veiculoService = $veiculoService;
    }

    public function index(): View
    {
        $veiculos = $this->veiculoService->listarPaginado();

        return view('veiculos.index', compact('veiculos'));
    }

    public function create(): View
    {
        return view('veiculos.create');
    }

    public function store(StoreVeiculoRequest $request): RedirectResponse
    {
        $this->veiculoService->cadastrar($request->validated());

        return redirect()
            ->route('veiculos.index')
            ->with('success', 'Veículo cadastrado com sucesso!');
    }

    public function show(int $id): View|RedirectResponse
    {
        $veiculo = $this->veiculoService->buscarPorId($id);

        if (!$veiculo) {
            return redirect()
                ->route('veiculos.index')
                ->with('error', 'Veículo não encontrado.');
        }

        return view('veiculos.show', compact('veiculo'));
    }

    public function edit(int $id): View|RedirectResponse
    {
        $veiculo = $this->veiculoService->buscarPorId($id);

        if (!$veiculo) {
            return redirect()
                ->route('veiculos.index')
                ->with('error', 'Veículo não encontrado.');
        }

        return view('veiculos.edit', compact('veiculo'));
    }

    public function update(UpdateVeiculoRequest $request, int $id): RedirectResponse
    {
        $veiculo = $this->veiculoService->atualizar(
            $id,
            $request->validated()
        );

        if (!$veiculo) {
            return redirect()
                ->route('veiculos.index')
                ->with('error', 'Veículo não encontrado.');
        }

        return redirect()
            ->route('veiculos.index')
            ->with('success', 'Veículo atualizado com sucesso!');
    }

    public function destroy(int $id): RedirectResponse
    {
        $excluido = $this->veiculoService->excluir($id);

        if (!$excluido) {
            return redirect()
                ->route('veiculos.index')
                ->with('error', 'Veículo não encontrado.');
        }

        return redirect()
            ->route('veiculos.index')
            ->with('success', 'Veículo excluído com sucesso!');
    }
}