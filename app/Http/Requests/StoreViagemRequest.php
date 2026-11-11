<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreViagemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id_veiculo' => 'required|integer|exists:veiculos,id_veiculo',
            'id_motorista' => 'required|integer|exists:motoristas,id_motorista',
            'km_inicial' => 'required|integer|min:0',
            'destino' => 'required|string|max:100',
            'finalidade' => 'nullable|string|max:255',
        ];
    }

    public function messages(): array
    {
        return [
            'id_veiculo.required' => 'Selecione um veículo.',
            'id_veiculo.exists' => 'O veículo selecionado não existe.',
            'id_motorista.required' => 'Selecione um motorista.',
            'id_motorista.exists' => 'O motorista selecionado não existe.',
            'km_inicial.required' => 'Informe a quilometragem inicial.',
            'destino.required' => 'Informe o destino da viagem.',
        ];
    }
}