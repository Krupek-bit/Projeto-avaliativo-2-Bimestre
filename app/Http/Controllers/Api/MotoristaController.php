<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMotoristaRequest;
use App\Http\Requests\UpdateMotoristaRequest;
use App\Http\Resources\MotoristaResource;
use App\Services\MotoristaService;
use Illuminate\Http\JsonResponse;

class MotoristaController extends Controller
{
    public function __construct(private MotoristaService $motoristaService) {}

    public function index()
    {
        return MotoristaResource::collection($this->motoristaService->listarPaginado());
    }

    public function store(StoreMotoristaRequest $request)
    {
        $motorista = $this->motoristaService->cadastrar($request->validated());

        return (new MotoristaResource($motorista))
            ->response()
            ->setStatusCode(201);
    }

    public function show(int $id)
    {
        $motorista = $this->motoristaService->buscarPorId($id);

        if (! $motorista) {
            return $this->notFoundResponse();
        }

        return new MotoristaResource($motorista);
    }

    public function update(UpdateMotoristaRequest $request, int $id)
    {
        $motorista = $this->motoristaService->atualizar($id, $request->validated());

        if (! $motorista) {
            return $this->notFoundResponse();
        }

        return new MotoristaResource($motorista);
    }

    public function destroy(int $id): JsonResponse
    {
        if (! $this->motoristaService->excluir($id)) {
            return $this->notFoundResponse();
        }

        return response()->json(['message' => 'Motorista excluído com sucesso.']);
    }

    private function notFoundResponse(): JsonResponse
    {
        return response()->json(['message' => 'Motorista não encontrado.'], 404);
    }
}
