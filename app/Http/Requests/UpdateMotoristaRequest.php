<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateMotoristaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $motorista = $this->route('motorista');

        $id = is_object($motorista)
            ? $motorista->id_motorista
            : $motorista;

        return [
            'nome' => ['required', 'string', 'max:100'],

            'cnh' => [
                'required',
                'string',
                'max:20',
                Rule::unique('motoristas', 'cnh')
                    ->ignore($id, 'id_motorista'),
            ],

            'categoria_cnh' => ['required', 'string', 'max:5'],
            'telefone' => ['nullable', 'string', 'max:20'],
            'data_admissao' => ['required', 'date'],
            'status' => ['required', 'string', 'max:20'],
        ];
    }

    public function messages(): array
    {
        return [
            'nome.required' => 'O nome do motorista é obrigatório.',
            'nome.max' => 'O nome não pode ultrapassar 100 caracteres.',
            'cnh.required' => 'A CNH é obrigatória.',
            'cnh.unique' => 'Esta CNH já pertence a outro motorista.',
            'categoria_cnh.required' => 'A categoria da CNH é obrigatória.',
            'categoria_cnh.max' => 'A categoria não pode ultrapassar 5 caracteres.',
            'telefone.max' => 'O telefone não pode ultrapassar 20 caracteres.',
            'data_admissao.required' => 'A data de admissão é obrigatória.',
            'data_admissao.date' => 'Informe uma data válida.',
            'status.required' => 'O status é obrigatório.',
            'status.max' => 'O status não pode ultrapassar 20 caracteres.',
        ];
    }
}
