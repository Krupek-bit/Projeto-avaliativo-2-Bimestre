@extends('layouts.app')
@section('titulo', 'Nova manutenção')

@section('content')
<h1 class="h3 mb-3">Nova manutenção</h1>
<form method="POST" action="{{ route('manutencoes.store') }}">
  @csrf
  @include('manutencoes._form')
</form>
@endsection