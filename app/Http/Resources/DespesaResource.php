<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DespesaResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_despesa' => $this->id_despesa,
            'id_veiculo' => $this->id_veiculo,
            'data_despesa' => $this->data_despesa?->toDateString(),
            'tipo_despesa' => $this->tipo_despesa,
            'descricao' => $this->descricao,
            'valor' => $this->valor,
            'veiculo' => new VeiculoResource($this->whenLoaded('veiculo')),
        ];
    }
}
