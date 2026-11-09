<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HistoricoStatusVeiculo extends Model
{
    protected $table = 'historico_status_veiculo';

    protected $primaryKey = 'id_historico';

    public $timestamps = false;

    protected $fillable = [
        'id_veiculo',
        'status_anterior',
        'status_novo',
        'data_alteracao',
    ];

    protected function casts(): array
    {
        return [
            'data_alteracao' => 'datetime',
        ];
    }

    public function veiculo(): BelongsTo
    {
        return $this->belongsTo(
            Veiculo::class,
            'id_veiculo',
            'id_veiculo'
        );
    }
}
