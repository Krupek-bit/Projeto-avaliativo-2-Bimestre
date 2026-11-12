<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AbastecimentoResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_abastecimento' => $this->id_abastecimento,
            'id_veiculo' => $this->id_veiculo,
            'data_abastecimento' => $this->data_abastecimento?->toDateString(),
            'tipo_combustivel' => $this->tipo_combustivel,
            'litros' => $this->litros,
            'valor_litro' => $this->valor_litro,
            'valor_total' => $this->valor_total,
            'quilometragem' => $this->quilometragem,
            'veiculo' => new VeiculoResource($this->whenLoaded('veiculo')),
        ];
    }
}
