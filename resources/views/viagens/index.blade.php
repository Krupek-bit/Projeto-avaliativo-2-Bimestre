@extends('layouts.app')

@section('titulo', 'Viagens')

@section('content')

<div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mb-3">

    <h1 class="h3 mb-0">Viagens</h1>

    <a href="{{ route('viagens.create') }}" class="btn btn-primary">
        Nova viagem
    </a>

</div>

<div class="table-responsive">

    <table class="table table-striped table-hover bg-white align-middle">

        <thead>
            <tr>
                <th>Veículo</th>
                <th>Motorista</th>
                <th>Destino</th>
                <th>Km inicial</th>
                <th>Saída</th>
                <th>Retorno</th>
                <th>Status</th>
                <th class="text-end">Ações</th>
            </tr>
        </thead>

        <tbody>

            @forelse($viagens as $v)

                <tr>

                    <td>
                        {{ $v->veiculo?->placa ?? '-' }}
                    </td>

                    <td>
                        {{ $v->motorista?->nome ?? '-' }}
                    </td>

                    <td>
                        {{ $v->destino }}
                    </td>

                    <td>
                        {{ number_format($v->km_inicial, 0, ',', '.') }} km
                    </td>

                    <td>
                        {{ $v->data_saida?->format('d/m/Y H:i') ?? '-' }}
                    </td>

                    <td>
                        {{ $v->data_retorno?->format('d/m/Y H:i') ?? '-' }}
                    </td>

                    <td>

                        @if($v->data_retorno)
                            <span class="badge text-bg-success">
                                Finalizada
                            </span>
                        @else
                            <span class="badge text-bg-primary">
                                Em andamento
                            </span>
                        @endif

                    </td>

                    <td class="text-end">

                        <a href="{{ route('viagens.show', $v->id_viagem) }}"
                           class="btn btn-sm btn-outline-secondary">
                            Visualizar
                        </a>

                    </td>

                </tr>

            @empty

                <tr>
                    <td colspan="8" class="text-center text-muted py-4">
                        Nenhuma viagem cadastrada.
                    </td>
                </tr>

            @endforelse

        </tbody>

    </table>

</div>

{{ $viagens->links('pagination::bootstrap-5') }}

@endsection
