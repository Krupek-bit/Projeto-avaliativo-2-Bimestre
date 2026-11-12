<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreManutencaoRequest;
use App\Http\Resources\ManutencaoResource;
use App\Services\ManutencaoService;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;

class ManutencaoController extends Controller
{
    public function __construct(private ManutencaoService $manutencaoService) {}

    public function index()
    {
        return ManutencaoResource::collection($this->manutencaoService->listar());
    }

    public function store(StoreManutencaoRequest $request): JsonResponse
    {
        try {
            $this->manutencaoService->registrar($request->validated());

            return response()->json(['message' => 'Manutenção registrada com sucesso.'], 201);
        } catch (QueryException) {
            return response()->json([
                'message' => 'Não foi possível registrar a manutenção. Verifique se o veículo está disponível e a quilometragem está correta.',
            ], 422);
        }
    }

    public function show(int $id)
    {
        $manutencao = $this->manutencaoService->buscarPorId($id);

        if (! $manutencao) {
            return $this->notFoundResponse();
        }

        return new ManutencaoResource($manutencao);
    }

    public function concluir(int $id): JsonResponse
    {
        $manutencao = $this->manutencaoService->buscarPorId($id);

        if (! $manutencao) {
            return $this->notFoundResponse();
        }

        try {
            $this->manutencaoService->concluir($manutencao->id_veiculo);

            return response()->json(['message' => 'Manutenção concluída e veículo liberado.']);
        } catch (QueryException) {
            return response()->json([
                'message' => 'O veículo desta manutenção não está aguardando conclusão.',
            ], 422);
        }
    }

    private function notFoundResponse(): JsonResponse
    {
        return response()->json(['message' => 'Manutenção não encontrada.'], 404);
    }
}
