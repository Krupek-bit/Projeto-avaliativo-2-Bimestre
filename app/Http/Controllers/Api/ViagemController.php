<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\FinalizarViagemRequest;
use App\Http\Requests\StoreViagemRequest;
use App\Http\Resources\ViagemResource;
use App\Services\ViagemService;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;

class ViagemController extends Controller
{
    public function __construct(private ViagemService $viagemService) {}

    public function index()
    {
        return ViagemResource::collection($this->viagemService->listar());
    }

    public function store(StoreViagemRequest $request): JsonResponse
    {
        try {
            $this->viagemService->iniciar($request->validated());

            return response()->json(['message' => 'Viagem iniciada com sucesso.'], 201);
        } catch (QueryException) {
            return response()->json([
                'message' => 'Não foi possível iniciar a viagem. Verifique o veículo, o motorista e a quilometragem.',
            ], 422);
        }
    }

    public function show(int $id)
    {
        $viagem = $this->viagemService->buscarPorId($id);

        if (! $viagem) {
            return $this->notFoundResponse();
        }

        return new ViagemResource($viagem);
    }

    public function finalizar(FinalizarViagemRequest $request, int $id): JsonResponse
    {
        try {
            $this->viagemService->finalizar($id, $request->integer('km_final'));

            return response()->json(['message' => 'Viagem finalizada com sucesso.']);
        } catch (QueryException) {
            return response()->json([
                'message' => 'Não foi possível finalizar a viagem. Verifique se ela está em andamento e se a quilometragem está correta.',
            ], 422);
        }
    }

    private function notFoundResponse(): JsonResponse
    {
        return response()->json(['message' => 'Viagem não encontrada.'], 404);
    }
}
