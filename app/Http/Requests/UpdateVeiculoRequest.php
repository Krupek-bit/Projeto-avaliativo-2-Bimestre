<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateVeiculoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $veiculo = $this->route('veiculo');

        $id = is_object($veiculo)
            ? $veiculo->id_veiculo
            : $veiculo;

        return [
            'placa' => [
                'required',
                'string',
                'max:10',
                Rule::unique('veiculos', 'placa')
                    ->ignore($id, 'id_veiculo'),
            ],
            'marca' => ['required', 'string', 'max:50'],
            'modelo' => ['required', 'string', 'max:50'],
            'ano' => ['required', 'integer', 'min:1900', 'max:' . (date('Y') + 1)],
            'tipo' => ['required', 'string', 'max:30'],
            'capacidade' => ['nullable', 'numeric', 'min:0'],
            'status' => ['required', 'in:ativo,em_viagem,em_manutencao,inativo'],
            'quilometragem_atual' => ['required', 'integer', 'min:0'],
        ];
    }

    public function messages(): array
    {
        return [
            'placa.required' => 'A placa do veículo é obrigatória.',
            'placa.unique' => 'Já existe outro veículo cadastrado com esta placa.',
            'marca.required' => 'A marca é obrigatória.',
            'modelo.required' => 'O modelo é obrigatório.',
            'ano.required' => 'O ano é obrigatório.',
            'tipo.required' => 'O tipo do veículo é obrigatório.',
            'status.required' => 'O status é obrigatório.',
            'quilometragem_atual.required' => 'A quilometragem atual é obrigatória.',
            'quilometragem_atual.integer' => 'A quilometragem deve ser um número inteiro.',
            'quilometragem_atual.min' => 'A quilometragem não pode ser negativa.',
        ];
    }
}
