<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class FinalizarViagemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'km_final' => 'required|integer|min:0',
        ];
    }

    public function messages(): array
    {
        return [
            'km_final.required' => 'Informe a quilometragem final.',
            'km_final.integer' => 'A quilometragem deve ser um número inteiro.',
            'km_final.min' => 'A quilometragem não pode ser negativa.',
        ];
    }
}