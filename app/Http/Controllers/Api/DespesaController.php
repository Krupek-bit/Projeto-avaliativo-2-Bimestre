<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreDespesaRequest;
use App\Http\Requests\UpdateDespesaRequest;
use App\Http\Resources\DespesaResource;
use App\Services\DespesaService;
use Illuminate\Http\JsonResponse;

class DespesaController extends Controller
{
    public function __construct(private DespesaService $despesaService) {}

    public function index()
    {
        return DespesaResource::collection($this->despesaService->listar());
    }

    public function store(StoreDespesaRequest $request)
    {
        $despesa = $this->despesaService->cadastrar($request->validated());

        return (new DespesaResource($despesa))
            ->response()
            ->setStatusCode(201);
    }

    public function show(int $id)
    {
        $despesa = $this->despesaService->buscarPorId($id);

        if (! $despesa) {
            return $this->notFoundResponse();
        }

        return new DespesaResource($despesa);
    }

    public function update(UpdateDespesaRequest $request, int $id)
    {
        $despesa = $this->despesaService->atualizar($id, $request->validated());

        if (! $despesa) {
            return $this->notFoundResponse();
        }

        return new DespesaResource($despesa);
    }

    public function destroy(int $id): JsonResponse
    {
        if (! $this->despesaService->excluir($id)) {
            return $this->notFoundResponse();
        }

        return response()->json(['message' => 'Despesa excluída com sucesso.']);
    }

    private function notFoundResponse(): JsonResponse
    {
        return response()->json(['message' => 'Despesa não encontrada.'], 404);
    }
}
