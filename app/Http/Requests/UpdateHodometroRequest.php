<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateHodometroRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id_veiculo' => 'required|integer|exists:gabriel_trabalho_bd.veiculos,id_veiculo',
            'data_registro' => 'required|date',
            'quilometragem' => 'required|integer|min:0',
            'observacao' => 'nullable|string|max:255',
        ];
    }

    public function messages(): array
    {
        return [
            'id_veiculo.required' => 'Selecione um veículo.',
            'id_veiculo.exists' => 'O veículo selecionado não existe.',
            'data_registro.required' => 'Informe a data do registro.',
            'quilometragem.required' => 'Informe a quilometragem.',
            'quilometragem.min' => 'A quilometragem não pode ser negativa.',
        ];
    }
}