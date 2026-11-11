<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateAbastecimentoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id_veiculo' => 'required|integer|exists:veiculos,id_veiculo',
            'data_abastecimento' => 'required|date',
            'tipo_combustivel' => 'required|string|max:30',
            'litros' => 'required|numeric|gt:0',
            'valor_litro' => 'required|numeric|gte:0',
            'quilometragem' => 'required|integer|min:0',
        ];
    }

    public function messages(): array
    {
        return [
            'id_veiculo.required' => 'Selecione um veículo.',
            'id_veiculo.exists' => 'O veículo selecionado não existe.',
            'data_abastecimento.required' => 'Informe a data do abastecimento.',
            'tipo_combustivel.required' => 'Informe o tipo de combustível.',
            'litros.required' => 'Informe a quantidade de litros.',
            'litros.gt' => 'A quantidade de litros deve ser maior que zero.',
            'valor_litro.required' => 'Informe o valor por litro.',
            'quilometragem.required' => 'Informe a quilometragem.',
        ];
    }
}