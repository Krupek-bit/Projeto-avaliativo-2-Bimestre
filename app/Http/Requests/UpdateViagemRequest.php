<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateViagemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id_veiculo' => [
                'required',
                'integer',
                'exists:gabriel_trabalho_bd.veiculos,id_veiculo',
            ],
            'id_motorista' => [
                'required',
                'integer',
                'exists:gabriel_trabalho_bd.motoristas,id_motorista',
            ],
            'data_saida' => ['required', 'date'],
            'data_retorno' => ['nullable', 'date', 'after_or_equal:data_saida'],
            'km_inicial' => ['required', 'integer', 'min:0'],
            'km_final' => ['nullable', 'integer', 'gte:km_inicial'],
            'destino' => ['required', 'string', 'max:100'],
            'finalidade' => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'id_veiculo.required' => 'Selecione um veículo.',
            'id_veiculo.exists' => 'O veículo selecionado não existe.',
            'id_motorista.required' => 'Selecione um motorista.',
            'id_motorista.exists' => 'O motorista selecionado não existe.',
            'data_saida.required' => 'A data de saída é obrigatória.',
            'data_retorno.after_or_equal' => 'A data de retorno não pode ser anterior à saída.',
            'km_inicial.required' => 'A quilometragem inicial é obrigatória.',
            'km_inicial.min' => 'A quilometragem inicial não pode ser negativa.',
            'km_final.gte' => 'A quilometragem final não pode ser menor que a inicial.',
            'destino.required' => 'O destino é obrigatório.',
            'destino.max' => 'O destino não pode ultrapassar 100 caracteres.',
        ];
    }
}
