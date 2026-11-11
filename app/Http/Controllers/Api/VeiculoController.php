<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreVeiculoRequest;
use App\Http\Requests\UpdateVeiculoRequest;
use App\Http\Resources\VeiculoResource;
use App\Services\VeiculoService;
use Illuminate\Http\JsonResponse;

class VeiculoController extends Controller
{
    public function __construct(
        private VeiculoService $veiculoService
    ) {}

    public function index()
    {
        $veiculos = $this->veiculoService->listar();

        return VeiculoResource::collection($veiculos);
    }

    public function store(StoreVeiculoRequest $request)
    {
        $veiculo = $this->veiculoService->cadastrar(
            $request->validated()
        );

        return (new VeiculoResource($veiculo))
            ->response()
            ->setStatusCode(201);
    }

    public function show(int $id)
    {
        $veiculo = $this->veiculoService->buscarPorId($id);

        if (!$veiculo) {
            return response()->json([
                'message' => 'Veículo não encontrado.'
            ], 404);
        }

        return new VeiculoResource($veiculo);
    }

    public function update(UpdateVeiculoRequest $request, int $id)
    {
        $veiculo = $this->veiculoService->atualizar(
            $id,
            $request->validated()
        );

        if (!$veiculo) {
            return response()->json([
                'message' => 'Veículo não encontrado.'
            ], 404);
        }

        return new VeiculoResource($veiculo);
    }

    public function destroy(int $id): JsonResponse
    {
        $excluido = $this->veiculoService->excluir($id);

        if (!$excluido) {
            return response()->json([
                'message' => 'Veículo não encontrado.'
            ], 404);
        }

        return response()->json([
            'message' => 'Veículo excluído com sucesso.'
        ], 200);
    }
}
