<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreDespesaRequest;
use App\Http\Requests\UpdateDespesaRequest;
use App\Services\DespesaService;
use App\Services\VeiculoService;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

class DespesaController extends Controller
{
    public function __construct(
        private DespesaService $despesaService,
        private VeiculoService $veiculoService,
    ) {}

    public function index(): View
    {
        $despesas = $this->despesaService->listar();

        return view('despesas.index', compact('despesas'));
    }

    public function create(): View
    {
        $veiculos = $this->veiculoService->listar();

        return view('despesas.create', compact('veiculos'));
    }

    public function store(StoreDespesaRequest $request): RedirectResponse
    {
        $this->despesaService->cadastrar($request->validated());

        return redirect()
            ->route('despesas.index')
            ->with('success', 'Despesa cadastrada com sucesso!');
    }

    public function edit(int $id): View|RedirectResponse
    {
        $despesa = $this->despesaService->buscarPorId($id);

        if (! $despesa) {
            return redirect()
                ->route('despesas.index')
                ->with('error', 'Despesa não encontrada.');
        }

        $veiculos = $this->veiculoService->listar();

        return view('despesas.edit', compact('despesa', 'veiculos'));
    }

    public function update(UpdateDespesaRequest $request, int $id): RedirectResponse
    {
        $despesa = $this->despesaService->atualizar($id, $request->validated());

        if (! $despesa) {
            return redirect()
                ->route('despesas.index')
                ->with('error', 'Despesa não encontrada.');
        }

        return redirect()
            ->route('despesas.index')
            ->with('success', 'Despesa atualizada com sucesso!');
    }

    public function destroy(int $id): RedirectResponse
    {
        if (! $this->despesaService->excluir($id)) {
            return redirect()
                ->route('despesas.index')
                ->with('error', 'Despesa não encontrada.');
        }

        return redirect()
            ->route('despesas.index')
            ->with('success', 'Despesa excluída com sucesso!');
    }
}
