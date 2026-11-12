<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreAbastecimentoRequest;
use App\Http\Requests\UpdateAbastecimentoRequest;
use App\Services\AbastecimentoService;
use App\Services\VeiculoService;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

class AbastecimentoController extends Controller
{
    public function __construct(
        private AbastecimentoService $abastecimentoService,
        private VeiculoService $veiculoService,
    ) {}

    public function index(): View
    {
        $abastecimentos = $this->abastecimentoService->listar();

        return view('abastecimentos.index', compact('abastecimentos'));
    }

    public function create(): View
    {
        $veiculos = $this->veiculoService->listar();

        return view('abastecimentos.create', compact('veiculos'));
    }

    public function store(StoreAbastecimentoRequest $request): RedirectResponse
    {
        $this->abastecimentoService->registrar($request->validated());

        return redirect()
            ->route('abastecimentos.index')
            ->with('success', 'Abastecimento registrado com sucesso!');
    }

    public function edit(int $id): View|RedirectResponse
    {
        $abastecimento = $this->abastecimentoService->buscarPorId($id);

        if (! $abastecimento) {
            return redirect()
                ->route('abastecimentos.index')
                ->with('error', 'Abastecimento não encontrado.');
        }

        $veiculos = $this->veiculoService->listar();

        return view('abastecimentos.edit', compact('abastecimento', 'veiculos'));
    }

    public function update(UpdateAbastecimentoRequest $request, int $id): RedirectResponse
    {
        $abastecimento = $this->abastecimentoService->atualizar(
            $id,
            $request->validated(),
        );

        if (! $abastecimento) {
            return redirect()
                ->route('abastecimentos.index')
                ->with('error', 'Abastecimento não encontrado.');
        }

        return redirect()
            ->route('abastecimentos.index')
            ->with('success', 'Abastecimento atualizado com sucesso!');
    }

    public function destroy(int $id): RedirectResponse
    {
        if (! $this->abastecimentoService->excluir($id)) {
            return redirect()
                ->route('abastecimentos.index')
                ->with('error', 'Abastecimento não encontrado.');
        }

        return redirect()
            ->route('abastecimentos.index')
            ->with('success', 'Abastecimento excluído com sucesso!');
    }
}
