<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateDespesaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id_veiculo' => 'required|integer|exists:veiculos,id_veiculo',
            'data_despesa' => 'required|date',
            'tipo_despesa' => 'required|string|max:50',
            'descricao' => 'required|string|max:255',
            'valor' => 'required|numeric|min:0',
        ];
    }

    public function messages(): array
    {
        return [
            'id_veiculo.required' => 'Selecione um veículo.',
            'id_veiculo.exists' => 'O veículo selecionado não existe.',
            'data_despesa.required' => 'Informe a data da despesa.',
            'tipo_despesa.required' => 'Informe o tipo da despesa.',
            'descricao.required' => 'Informe a descrição da despesa.',
            'valor.required' => 'Informe o valor da despesa.',
            'valor.min' => 'O valor não pode ser negativo.',
        ];
    }
}