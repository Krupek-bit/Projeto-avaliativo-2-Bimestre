<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreViagemRequest;
use App\Http\Requests\FinalizarViagemRequest;
use App\Models\Motorista;
use App\Models\Veiculo;
use App\Services\ViagemService;
use Illuminate\Database\QueryException;

class ViagemController extends Controller
{
    public function __construct(
        private ViagemService $viagemService
    ) {}

    public function index()
    {
        $viagens = $this->viagemService->listar();

        return view('viagens.index', compact('viagens'));
    }

    public function create()
    {
        $veiculos = Veiculo::where('status', 'ativo')->get();
        $motoristas = Motorista::all();

        return view('viagens.create', compact(
            'veiculos',
            'motoristas'
        ));
    }

    public function store(StoreViagemRequest $request)
    {
        try {
            $this->viagemService->iniciar($request->validated());

            return redirect()
                ->route('viagens.index')
                ->with('success', 'Viagem iniciada com sucesso!');

        } catch (QueryException $e) {
            return back()
                ->withInput()
                ->withErrors([
                    'viagem' => 'Não foi possível iniciar a viagem. Verifique o veículo, o motorista e a quilometragem.',
                ]);
        }
    }
    
    public function show(int $id)
    {
        $viagem = $this->viagemService->buscarPorId($id);

        if (!$viagem) {
            return redirect()
                ->route('viagens.index')
                ->with('error', 'Viagem não encontrada.');
        }

        return view('viagens.show', compact('viagem'));
    }

    public function finalizar(
        FinalizarViagemRequest $request,
        int $id
    ) {
        try {
            $this->viagemService->finalizar(
                $id,
                (int) $request->validated('km_final')
            );

            return redirect()
                ->route('viagens.index')
                ->with('success', 'Viagem finalizada com sucesso!');
        } catch (QueryException $e) {
            return back()
                ->withInput()
                ->withErrors([
                    'viagem' => 'Não foi possível finalizar a viagem. Verifique se ela ainda está em andamento e se a quilometragem está correta.',
                ]);
        }
    }
}
