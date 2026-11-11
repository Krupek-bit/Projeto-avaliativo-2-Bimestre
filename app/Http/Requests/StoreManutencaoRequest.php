<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreManutencaoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id_veiculo' => 'required|integer|exists:veiculos,id_veiculo',
            'data_manutencao' => 'required|date',
            'tipo_manutencao' => 'required|string|max:50',
            'descricao' => 'required|string|max:255',
            'oficina' => 'nullable|string|max:100',
            'valor' => 'required|numeric|min:0',
            'quilometragem' => 'required|integer|min:0',
        ];
    }

    public function messages(): array
    {
        return [
            'id_veiculo.required' => 'Selecione um veículo.',
            'id_veiculo.exists' => 'O veículo selecionado não existe.',
            'data_manutencao.required' => 'Informe a data da manutenção.',
            'tipo_manutencao.required' => 'Informe o tipo de manutenção.',
            'descricao.required' => 'Informe a descrição da manutenção.',
            'valor.required' => 'Informe o valor da manutenção.',
            'valor.min' => 'O valor não pode ser negativo.',
            'quilometragem.required' => 'Informe a quilometragem.',
        ];
    }
}