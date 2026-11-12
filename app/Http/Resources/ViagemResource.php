<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ViagemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_viagem' => $this->id_viagem,
            'id_veiculo' => $this->id_veiculo,
            'id_motorista' => $this->id_motorista,
            'data_saida' => $this->data_saida?->toDateTimeString(),
            'data_retorno' => $this->data_retorno?->toDateTimeString(),
            'km_inicial' => $this->km_inicial,
            'km_final' => $this->km_final,
            'destino' => $this->destino,
            'finalidade' => $this->finalidade,
            'veiculo' => new VeiculoResource($this->whenLoaded('veiculo')),
            'motorista' => new MotoristaResource($this->whenLoaded('motorista')),
        ];
    }
}
