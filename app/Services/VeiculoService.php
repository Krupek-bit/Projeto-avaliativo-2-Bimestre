<?php

namespace App\Services;

use App\Models\Veiculo;
use Illuminate\Database\Eloquent\Collection;

class VeiculoService
{
    public function listar(): Collection
    {
        return Veiculo::all();
    }

    public function buscarPorId(int $id): ?Veiculo
    {
        return Veiculo::find($id);
    }

    public function cadastrar(array $dados): Veiculo
    {
        return Veiculo::create($dados);
    }

    public function atualizar(int $id, array $dados): ?Veiculo
    {
        $veiculo = Veiculo::find($id);

        if (!$veiculo) {
            return null;
        }

        $veiculo->update($dados);

        return $veiculo->refresh();
    }

    public function excluir(int $id): bool
    {
        $veiculo = Veiculo::find($id);

        if (!$veiculo) {
            return false;
        }

        return (bool) $veiculo->delete();
    }
}
