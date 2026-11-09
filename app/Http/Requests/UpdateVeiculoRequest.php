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
                Rule::unique('gabriel_trabalho_bd.veiculos', 'placa')
                    ->ignore($id, 'id_veiculo'),
            ],

            'marca' => ['required', 'string', 'max:50'],
            'modelo' => ['required', 'string', 'max:50'],
            'ano' => ['required', 'integer', 'min:1900', 'max:' . (date('Y') + 1)],
            'tipo' => ['required', 'string', 'max:30'],
            'capacidade' => ['nullable', 'numeric', 'min:0'],
            'status' => [
                'required',
                Rule::in([
                    'ativo',
                    'em_viagem',
                    'em_manutencao',
                    'inativo',
                ]),
            ],
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
            'ano.min' => 'O ano informado é inválido.',
            'ano.max' => 'O ano não pode ser superior ao próximo ano.',
            'tipo.required' => 'O tipo do veículo é obrigatório.',
            'capacidade.numeric' => 'A capacidade deve ser um número.',
            'capacidade.min' => 'A capacidade não pode ser negativa.',
            'status.required' => 'O status é obrigatório.',
            'status.in' => 'O status informado é inválido.',
        ];
    }
}
