<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MotoristaResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_motorista' => $this->id_motorista,
            'nome' => $this->nome,
            'cnh' => $this->cnh,
            'categoria_cnh' => $this->categoria_cnh,
            'telefone' => $this->telefone,
            'data_admissao' => $this->data_admissao?->toDateString(),
            'validade_cnh' => $this->validade_cnh?->toDateString(),
            'status' => $this->status,
        ];
    }
}
