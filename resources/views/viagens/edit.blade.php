@extends('layouts.app')
@section('titulo', 'Editar viagem')

@section('content')
<h1 class="h3 mb-3">Editar viagem</h1>
<form method="POST" action="{{ route('viagens.update', $viagem) }}">
  @csrf
  @method('PUT')
  @include('viagens._form')
</form>
@endsection