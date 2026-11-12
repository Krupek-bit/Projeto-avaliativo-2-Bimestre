<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreMotoristaRequest;
use App\Http\Requests\UpdateMotoristaRequest;
use App\Services\MotoristaService;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

class MotoristaController extends Controller
{
    protected MotoristaService $motoristaService;

    public function __construct(MotoristaService $motoristaService)
    {
        $this->motoristaService = $motoristaService;
    }

    public function index(): View
    {
        $motoristas = $this->motoristaService->listarPaginado();

        return view('motoristas.index', compact('motoristas'));
    }

    public function create(): View
    {
        return view('motoristas.create');
    }

    public function store(StoreMotoristaRequest $request): RedirectResponse
    {
        $this->motoristaService->cadastrar($request->validated());

        return redirect()
            ->route('motoristas.index')
            ->with('success', 'Motorista cadastrado com sucesso!');
    }

    public function show(int $id): View|RedirectResponse
    {
        $motorista = $this->motoristaService->buscarPorId($id);

        if (!$motorista) {
            return redirect()
                ->route('motoristas.index')
                ->with('error', 'Motorista não encontrado.');
        }

        return view('motoristas.show', compact('motorista'));
    }

    public function edit(int $id): View|RedirectResponse
    {
        $motorista = $this->motoristaService->buscarPorId($id);

        if (!$motorista) {
            return redirect()
                ->route('motoristas.index')
                ->with('error', 'Motorista não encontrado.');
        }

        return view('motoristas.edit', compact('motorista'));
    }

    public function update(UpdateMotoristaRequest $request, int $id): RedirectResponse
    {
        $motorista = $this->motoristaService->atualizar(
            $id,
            $request->validated()
        );

        if (!$motorista) {
            return redirect()
                ->route('motoristas.index')
                ->with('error', 'Motorista não encontrado.');
        }

        return redirect()
            ->route('motoristas.index')
            ->with('success', 'Motorista atualizado com sucesso!');
    }

    public function destroy(int $id): RedirectResponse
    {
        $excluido = $this->motoristaService->excluir($id);

        if (!$excluido) {
            return redirect()
                ->route('motoristas.index')
                ->with('error', 'Motorista não encontrado.');
        }

        return redirect()
            ->route('motoristas.index')
            ->with('success', 'Motorista excluído com sucesso!');
    }
}