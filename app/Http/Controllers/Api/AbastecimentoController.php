<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreAbastecimentoRequest;
use App\Http\Requests\UpdateAbastecimentoRequest;
use App\Http\Resources\AbastecimentoResource;
use App\Services\AbastecimentoService;
use Illuminate\Http\JsonResponse;

class AbastecimentoController extends Controller
{
    public function __construct(private AbastecimentoService $abastecimentoService) {}

    public function index()
    {
        return AbastecimentoResource::collection($this->abastecimentoService->listar());
    }

    public function store(StoreAbastecimentoRequest $request)
    {
        $abastecimento = $this->abastecimentoService->registrar($request->validated());

        return (new AbastecimentoResource($abastecimento))
            ->response()
            ->setStatusCode(201);
    }

    public function show(int $id)
    {
        $abastecimento = $this->abastecimentoService->buscarPorId($id);

        if (! $abastecimento) {
            return $this->notFoundResponse();
        }

        return new AbastecimentoResource($abastecimento);
    }

    public function update(UpdateAbastecimentoRequest $request, int $id)
    {
        $abastecimento = $this->abastecimentoService->atualizar($id, $request->validated());

        if (! $abastecimento) {
            return $this->notFoundResponse();
        }

        return new AbastecimentoResource($abastecimento);
    }

    public function destroy(int $id): JsonResponse
    {
        if (! $this->abastecimentoService->excluir($id)) {
            return $this->notFoundResponse();
        }

        return response()->json(['message' => 'Abastecimento excluído com sucesso.']);
    }

    private function notFoundResponse(): JsonResponse
    {
        return response()->json(['message' => 'Abastecimento não encontrado.'], 404);
    }
}
