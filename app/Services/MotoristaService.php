<?php

namespace App\Services;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use App\Models\Motorista;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class MotoristaService
{
    public function listarPaginado(int $porPagina = 15): LengthAwarePaginator
    {
        return Motorista::paginate($porPagina);
    }

    public function buscarPorId(int $id): ?Motorista
    {
        return Motorista::find($id);
    }

    public function cadastrar(array $dados): Motorista
    {
        return Motorista::create($dados);
    }

    public function atualizar(int $id, array $dados): ?Motorista
    {
        $motorista = Motorista::find($id);

        if (!$motorista) {
            return null;
        }

        $motorista->update($dados);

        return $motorista->refresh();
    }

    public function excluir(int $id): bool
    {
        $motorista = Motorista::find($id);

        if (!$motorista) {
            return false;
        }

        return (bool) $motorista->delete();
    }

    // Funções PostgreSQL

    public function motoristaApto(int $idMotorista): mixed
    {
        return DB::scalar(
            'SELECT fn_motorista_apto(?)',
            [$idMotorista]
        );
    }

    public function totalViagens(int $idMotorista): mixed
    {
        return DB::scalar(
            'SELECT fn_total_viagens_motorista(?)',
            [$idMotorista]
        );
    }
}
