<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class VeiculoResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_veiculo' => $this->id_veiculo,
            'placa' => $this->placa,
            'marca' => $this->marca,
            'modelo' => $this->modelo,
            'ano' => $this->ano,
            'tipo' => $this->tipo,
            'capacidade' => $this->capacidade,
            'status' => $this->status,
            'quilometragem_atual' => $this->quilometragem_atual,
        ];
    }
}
