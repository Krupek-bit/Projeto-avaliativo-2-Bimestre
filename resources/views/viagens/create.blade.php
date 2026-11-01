@extends('layouts.app')
@section('titulo', 'Nova viagem')

@section('content')
<h1 class="h3 mb-3">Nova viagem</h1>
<form method="POST" action="{{ route('viagens.store') }}">
  @csrf
  @include('viagens._form')
</form>
@endsection