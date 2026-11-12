<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreManutencaoRequest;
use App\Services\ManutencaoService;
use App\Services\VeiculoService;
use Illuminate\Database\QueryException;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

class ManutencaoController extends Controller
{
    public function __construct(
        private ManutencaoService $manutencaoService,
        private VeiculoService $veiculoService,
    ) {}

    public function index(): View
    {
        $manutencoes = $this->manutencaoService->listar();

        return view('manutencoes.index', compact('manutencoes'));
    }

    public function create(): View
    {
        $veiculos = $this->veiculoService->listar();

        return view('manutencoes.create', compact('veiculos'));
    }

    public function store(StoreManutencaoRequest $request): RedirectResponse
    {
        try {
            $this->manutencaoService->registrar($request->validated());

            return redirect()
                ->route('manutencoes.index')
                ->with('success', 'Manutenção registrada com sucesso!');
        } catch (QueryException) {
            return back()
                ->withInput()
                ->withErrors([
                    'manutencao' => 'Não foi possível registrar a manutenção. Verifique se o veículo está disponível e a quilometragem está correta.',
                ]);
        }
    }

    public function concluir(int $id): RedirectResponse
    {
        $manutencao = $this->manutencaoService->buscarPorId($id);

        if (! $manutencao) {
            return redirect()
                ->route('manutencoes.index')
                ->with('error', 'Manutenção não encontrada.');
        }

        try {
            $this->manutencaoService->concluir($manutencao->id_veiculo);

            return redirect()
                ->route('manutencoes.index')
                ->with('success', 'Manutenção concluída e veículo liberado!');
        } catch (QueryException) {
            return redirect()
                ->route('manutencoes.index')
                ->with('error', 'O veículo desta manutenção não está aguardando conclusão.');
        }
    }
}
