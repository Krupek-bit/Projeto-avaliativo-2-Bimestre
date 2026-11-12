<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ManutencaoResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_manutencao' => $this->id_manutencao,
            'id_veiculo' => $this->id_veiculo,
            'data_manutencao' => $this->data_manutencao?->toDateString(),
            'tipo_manutencao' => $this->tipo_manutencao,
            'descricao' => $this->descricao,
            'oficina' => $this->oficina,
            'valor' => $this->valor,
            'quilometragem' => $this->quilometragem,
            'veiculo' => new VeiculoResource($this->whenLoaded('veiculo')),
        ];
    }
}
