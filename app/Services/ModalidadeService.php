<?php

namespace App\Services;

use App\Models\Modalidade;
use Illuminate\Database\Eloquent\Collection;

class ModalidadeService
{
    public function listar(): Collection
    {
        return Modalidade::orderBy('nome')->get();
    }

    public function buscarPorId(string $id): ?Modalidade
    {
        return Modalidade::find($id);
    }

    public function cadastrar(array $dados): Modalidade
    {
        return Modalidade::create($dados);
    }

    public function atualizar(string $id, array $dados): ?Modalidade
    {
        $modalidade = Modalidade::find($id);

        if (!$modalidade) {
            return null;
        }

        $modalidade->update($dados);

        return $modalidade->refresh();
    }

    public function excluir(string $id): bool
    {
        $modalidade = Modalidade::find($id);

        if (!$modalidade) {
            return false;
        }

        return (bool) $modalidade->delete();
    }
}
