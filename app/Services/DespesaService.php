<?php

namespace App\Services;

use App\Models\Despesa;
use Illuminate\Database\Eloquent\Collection;

class DespesaService
{
    public function listar(): Collection
    {
        return Despesa::with('veiculo')
            ->orderByDesc('data_despesa')
            ->orderByDesc('id_despesa')
            ->get();
    }

    public function buscarPorId(int $id): ?Despesa
    {
        return Despesa::with('veiculo')->find($id);
    }

    public function cadastrar(array $dados): Despesa
    {
        return Despesa::create($dados);
    }

    public function atualizar(int $id, array $dados): ?Despesa
    {
        $despesa = Despesa::find($id);

        if (!$despesa) {
            return null;
        }

        $despesa->update($dados);

        return $despesa->refresh();
    }

    public function excluir(int $id): bool
    {
        $despesa = Despesa::find($id);

        if (!$despesa) {
            return false;
        }

        return (bool) $despesa->delete();
    }
}
