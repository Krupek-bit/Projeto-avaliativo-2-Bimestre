<?php

namespace App\Services;

use App\Models\Veiculo;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class VeiculoService
{
    /**
     * Lista completa (Collection). Use em selects/formulários.
     */
    public function listar(): Collection
    {
        return Veiculo::all();
    }

    /**
     * Lista paginada. Use na tela de listagem (index) que chama ->links().
     */
    public function listarPaginado(int $porPagina = 15): LengthAwarePaginator
    {
        return Veiculo::paginate($porPagina);
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

    // Funções PostgreSQL

    public function consumoMedio(int $idVeiculo): mixed
    {
        return DB::scalar(
            'SELECT fn_consumo_medio(?)',
            [$idVeiculo]
        );
    }

    public function custoTotal(int $idVeiculo, string $inicio, string $fim): mixed
    {
        return DB::scalar(
            'SELECT fn_custo_total_veiculo(?, ?, ?)',
            [$idVeiculo, $inicio, $fim]
        );
    }

    public function gastoCombustivel(int $idVeiculo): mixed
    {
        return DB::scalar(
            'SELECT fn_gasto_combustivel(?)',
            [$idVeiculo]
        );
    }

    public function kmPercorridos(int $idVeiculo): mixed
    {
        return DB::scalar(
            'SELECT fn_km_percorridos(?)',
            [$idVeiculo]
        );
    }

    public function totalAbastecimentos(int $idVeiculo): mixed
    {
        return DB::scalar(
            'SELECT fn_total_abastecimentos(?)',
            [$idVeiculo]
        );
    }

    public function totalDespesas(int $idVeiculo): mixed
    {
        return DB::scalar(
            'SELECT fn_total_despesas(?)',
            [$idVeiculo]
        );
    }

    public function totalManutencao(int $idVeiculo): mixed
    {
        return DB::scalar(
            'SELECT fn_total_manutencao(?)',
            [$idVeiculo]
        );
    }
}