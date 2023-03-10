# frozen_string_literal: true

class Groups::Analytics::CycleAnalytics::ValueStreamsController < Groups::Analytics::ApplicationController
  respond_to :json

  before_action do
    render_403 unless can?(current_user, :read_group_cycle_analytics, @group)
  end

  before_action :load_stage_events, only: %i[new edit]
  before_action :load_value_stream, only: %i[show edit update]

  layout 'group'

  def index
    render json: Analytics::CycleAnalytics::ValueStreamSerializer.new.represent(value_streams)
  end

  def new
    render :new
  end

  def show
    render json: Analytics::CycleAnalytics::ValueStreamSerializer.new.represent(@value_stream)
  end

  def edit
    render :edit
  end

  def create
    result = Analytics::CycleAnalytics::ValueStreams::CreateService.new(namespace: @group, params: create_params, current_user: current_user).execute

    if result.success?
      render json: serialize_value_stream(result), status: result.http_status
    else
      render json: { message: result.message, payload: { errors: serialize_value_stream_error(result) } }, status: result.http_status
    end
  end

  def update
    result = Analytics::CycleAnalytics::ValueStreams::UpdateService.new(namespace: @group, params: update_params, current_user: current_user, value_stream: @value_stream).execute

    if result.success?
      render json: serialize_value_stream(result), status: result.http_status
    else
      render json: { message: result.message, payload: { errors: serialize_value_stream_error(result) } }, status: result.http_status
    end
  end

  def destroy
    value_stream = @group.value_streams.find(params[:id])

    if value_stream.custom?
      value_stream.delete
      render json: {}, status: :ok
    else
      render json: { message: s_('ValueStream|The Default Value Stream cannot be deleted') }, status: :unprocessable_entity
    end
  end

  private

  def value_stream_params
    params.require(:value_stream).permit(:name)
  end

  def create_params
    params.require(:value_stream).permit(:name, stages: stage_create_params).tap do |permitted_params|
      transform_stage_params(permitted_params)
    end
  end

  def update_params
    params.require(:value_stream).permit(:name, stages: stage_update_params).tap do |permitted_params|
      transform_stage_params(permitted_params)
    end
  end

  def transform_stage_params(permitted_params)
    Array(permitted_params[:stages]).each do |stage_params|
      next unless stage_params[:start_event] && stage_params[:end_event]

      # supporting the new API

      start_event = stage_params.delete(:start_event)
      end_event = stage_params.delete(:end_event)
      stage_params[:start_event_identifier] = start_event[:identifier]
      stage_params[:start_event_label_id] = start_event[:label_id]

      stage_params[:end_event_identifier] = end_event[:identifier]
      stage_params[:end_event_label_id] = end_event[:label_id]
    end
  end

  def stage_create_params
    [
      :name,
      :start_event_identifier,
      :start_event_label_id,
      :end_event_identifier,
      :end_event_label_id,
      :custom,
      {
        start_event: [:identifier, :label_id],
        end_event: [:identifier, :label_id]
      }
    ]
  end

  def stage_update_params
    stage_create_params + [:id]
  end

  def value_streams
    @value_streams ||= @group.value_streams.preload_associated_models
  end

  def serialize_value_stream(result)
    Analytics::CycleAnalytics::ValueStreamSerializer.new.represent(result.payload[:value_stream])
  end

  def serialize_value_stream_error(result)
    Analytics::CycleAnalytics::ValueStreamErrorsSerializer.new(result.payload[:value_stream])
  end

  def load_value_stream
    @value_stream ||= @group.value_streams.find(params[:id])
  end

  def load_stage_events
    @stage_events ||= begin
      selectable_events = Gitlab::Analytics::CycleAnalytics::StageEvents.selectable_events
      Analytics::CycleAnalytics::EventEntity.represent(selectable_events)
    end
  end
end
