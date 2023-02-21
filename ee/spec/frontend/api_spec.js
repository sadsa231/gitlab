import MockAdapter from 'axios-mock-adapter';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import { ContentTypeMultipartFormData } from '~/lib/utils/headers';
import { HTTP_STATUS_CREATED, HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('Api', () => {
  const dummyApiVersion = 'v3000';
  const dummyUrlRoot = '/gitlab';
  const dummyGon = {
    api_version: dummyApiVersion,
    relative_url_root: dummyUrlRoot,
  };

  let originalGon;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = { ...dummyGon };
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
  });

  describe('ldapGroups', () => {
    it('calls callback on completion', async () => {
      const query = 'query';
      const provider = 'provider';
      const callback = jest.fn();
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/ldap/${provider}/groups.json`;

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, [
        {
          name: 'test',
        },
      ]);

      const response = await Api.ldapGroups(query, provider, callback);
      expect(callback).toHaveBeenCalledWith(response);
    });
  });

  describe('createChildEpic', () => {
    it('calls `axios.post` using params `groupId`, `parentEpicIid` and title', async () => {
      const groupId = 'gitlab-org';
      const parentEpicId = 1;
      const title = 'Sample epic';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics`;
      const expectedRes = {
        title,
        id: 20,
        parentId: 5,
      };

      mock.onPost(expectedUrl).reply(HTTP_STATUS_OK, expectedRes);

      const { data } = await Api.createChildEpic({ groupId, parentEpicId, title });
      expect(data.title).toBe(expectedRes.title);
      expect(data.id).toBe(expectedRes.id);
      expect(data.parentId).toBe(expectedRes.parentId);
    });
  });

  describe('GroupActivityAnalytics', () => {
    const groupId = 'gitlab-org';

    describe('groupActivityMergeRequestsCount', () => {
      it('fetches the number of MRs created for a given group', () => {
        const response = { merge_requests_count: 10 };
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/analytics/group_activity/merge_requests_count`;

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, response);

        return Api.groupActivityMergeRequestsCount(groupId).then(({ data }) => {
          expect(data).toEqual(response);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl, { params: { group_path: groupId } });
        });
      });
    });

    describe('groupActivityIssuesCount', () => {
      it('fetches the number of issues created for a given group', async () => {
        const response = { issues_count: 20 };
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/analytics/group_activity/issues_count`;

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, response);

        const { data } = await Api.groupActivityIssuesCount(groupId);
        expect(data).toEqual(response);
        expect(axios.get).toHaveBeenCalledWith(expectedUrl, { params: { group_path: groupId } });
      });
    });

    describe('groupActivityNewMembersCount', () => {
      it('fetches the number of new members created for a given group', () => {
        const response = { new_members_count: 30 };
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/analytics/group_activity/new_members_count`;

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, response);

        return Api.groupActivityNewMembersCount(groupId).then(({ data }) => {
          expect(data).toEqual(response);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl, { params: { group_path: groupId } });
        });
      });
    });
  });

  describe('GeoReplicable', () => {
    let expectedUrl;
    let apiResponse;
    let mockParams;
    let mockReplicableType;

    beforeEach(() => {
      mockReplicableType = 'designs';
      expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/geo_replication/${mockReplicableType}`;
    });

    describe('getGeoReplicableItems', () => {
      it('fetches replicableItems based on replicableType', () => {
        apiResponse = [
          { id: 1, name: 'foo' },
          { id: 2, name: 'bar' },
        ];
        mockParams = { page: 1 };

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, apiResponse);

        return Api.getGeoReplicableItems(mockReplicableType, mockParams).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl, { params: mockParams });
        });
      });
    });

    describe('initiateAllGeoReplicableSyncs', () => {
      it('POSTs with correct action', () => {
        apiResponse = [{ status: 'ok' }];
        mockParams = {};

        const mockAction = 'reverify';

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'post');
        mock.onPost(`${expectedUrl}/${mockAction}`).replyOnce(HTTP_STATUS_CREATED, apiResponse);

        return Api.initiateAllGeoReplicableSyncs(mockReplicableType, mockAction).then(
          ({ data }) => {
            expect(data).toEqual(apiResponse);
            expect(axios.post).toHaveBeenCalledWith(`${expectedUrl}/${mockAction}`, mockParams);
          },
        );
      });
    });

    describe('initiateGeoReplicableSync', () => {
      it('PUTs with correct action and projectId', () => {
        apiResponse = [{ status: 'ok' }];
        mockParams = {};

        const mockAction = 'reverify';
        const mockProjectId = 1;

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'put');
        mock
          .onPut(`${expectedUrl}/${mockProjectId}/${mockAction}`)
          .replyOnce(HTTP_STATUS_CREATED, apiResponse);

        return Api.initiateGeoReplicableSync(mockReplicableType, {
          projectId: mockProjectId,
          action: mockAction,
        }).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.put).toHaveBeenCalledWith(
            `${expectedUrl}/${mockProjectId}/${mockAction}`,
            mockParams,
          );
        });
      });
    });
  });

  describe('changeVulnerabilityState', () => {
    it.each`
      id    | action
      ${5}  | ${'dismiss'}
      ${7}  | ${'confirm'}
      ${38} | ${'resolve'}
    `('POSTS to correct endpoint ($id, $action)', ({ id, action }) => {
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/vulnerabilities/${id}/${action}`;
      const expectedResponse = { id, action, test: 'test' };

      mock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK, expectedResponse);

      return Api.changeVulnerabilityState(id, action).then(({ data }) => {
        expect(mock.history.post).toContainEqual(expect.objectContaining({ url: expectedUrl }));
        expect(data).toEqual(expectedResponse);
      });
    });
  });

  describe('GeoNode', () => {
    let expectedUrl;
    let mockNode;

    beforeEach(() => {
      expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/geo_nodes`;
    });

    describe('createGeoNode', () => {
      it('POSTs with correct action', () => {
        mockNode = {
          name: 'Mock Node',
          url: 'https://mock_node.gitlab.com',
          primary: false,
        };

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'post');
        mock.onPost(expectedUrl).replyOnce(HTTP_STATUS_CREATED, mockNode);

        return Api.createGeoNode(mockNode).then(({ data }) => {
          expect(data).toEqual(mockNode);
          expect(axios.post).toHaveBeenCalledWith(expectedUrl, mockNode);
        });
      });
    });

    describe('updateGeoNode', () => {
      it('PUTs with correct action', () => {
        mockNode = {
          id: 1,
          name: 'Mock Node',
          url: 'https://mock_node.gitlab.com',
          primary: false,
        };

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'put');
        mock.onPut(`${expectedUrl}/${mockNode.id}`).replyOnce(HTTP_STATUS_CREATED, mockNode);

        return Api.updateGeoNode(mockNode).then(({ data }) => {
          expect(data).toEqual(mockNode);
          expect(axios.put).toHaveBeenCalledWith(`${expectedUrl}/${mockNode.id}`, mockNode);
        });
      });
    });

    describe('removeGeoNode', () => {
      it('DELETES with correct ID', () => {
        mockNode = {
          id: 1,
        };

        jest.spyOn(Api, 'buildUrl').mockReturnValue(`${expectedUrl}/${mockNode.id}`);
        jest.spyOn(axios, 'delete');
        mock.onDelete(`${expectedUrl}/${mockNode.id}`).replyOnce(HTTP_STATUS_OK, {});

        return Api.removeGeoNode(mockNode.id).then(() => {
          expect(axios.delete).toHaveBeenCalledWith(`${expectedUrl}/${mockNode.id}`);
        });
      });
    });
  });

  describe('Application Settings', () => {
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/application/settings`;
    const apiResponse = { mock_setting: 1, mock_setting2: 2, mock_setting3: 3 };

    describe('getApplicationSettings', () => {
      it('fetches applications settings', () => {
        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, apiResponse);

        return Api.getApplicationSettings().then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl);
        });
      });
    });

    describe('updateApplicationSettings', () => {
      const mockReq = { mock_setting: 10 };

      it('updates applications settings', () => {
        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'put');
        mock.onPut(expectedUrl).replyOnce(HTTP_STATUS_CREATED, apiResponse);

        return Api.updateApplicationSettings(mockReq).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.put).toHaveBeenCalledWith(expectedUrl, mockReq);
        });
      });
    });
  });

  describe('Project analytics: deployment frequency', () => {
    const projectPath = 'test/project';
    const encodedProjectPath = encodeURIComponent(projectPath);
    const params = { environment: 'production' };
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${encodedProjectPath}/analytics/deployment_frequency`;

    describe('deploymentFrequencies', () => {
      it('GETs the right url', async () => {
        mock.onGet(expectedUrl, { params }).replyOnce(HTTP_STATUS_OK, []);

        const { data } = await Api.deploymentFrequencies(projectPath, params);

        expect(data).toEqual([]);
      });
    });
  });

  describe('Issue metric images', () => {
    const projectId = 1;
    const issueIid = '2';
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/issues/${issueIid}/metric_images`;

    describe('fetchIssueMetricImages', () => {
      it('fetches a list of images', async () => {
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, []);

        await Api.fetchIssueMetricImages({ issueIid, id: projectId }).then(({ data }) => {
          expect(data).toEqual([]);
          expect(axios.get).toHaveBeenCalled();
        });
      });
    });

    describe('uploadIssueMetricImage', () => {
      const file = 'mock file';
      const url = 'mock url';
      const urlText = 'mock urlText';

      it('uploads an image', async () => {
        jest.spyOn(axios, 'post');
        mock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK, {});

        await Api.uploadIssueMetricImage({ issueIid, id: projectId, file, url, urlText }).then(
          ({ data }) => {
            expect(data).toEqual({});
            expect(axios.post.mock.calls[0][2]).toEqual({
              headers: { ...ContentTypeMultipartFormData },
            });
          },
        );
      });
    });
  });

  describe('deployment approvals', () => {
    const projectId = 1;
    const deploymentId = 2;
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/deployments/${deploymentId}/approval`;
    const comment = 'comment';

    it('sends an approval when approve is true', async () => {
      mock.onPost(expectedUrl, { status: 'approved', comment }).replyOnce(HTTP_STATUS_OK);

      await Api.deploymentApproval({ id: projectId, deploymentId, approve: true, comment });

      expect(mock.history.post.length).toBe(1);
      expect(mock.history.post[0].data).toBe(JSON.stringify({ status: 'approved', comment }));
    });

    it('sends a rejection when approve is false', async () => {
      mock.onPost(expectedUrl, { status: 'rejected', comment }).replyOnce(HTTP_STATUS_OK);

      await Api.deploymentApproval({ id: projectId, deploymentId, approve: false, comment });

      expect(mock.history.post.length).toBe(1);
      expect(mock.history.post[0].data).toBe(JSON.stringify({ status: 'rejected', comment }));
    });
  });

  describe('validatePaymentMethod', () => {
    it('submits the custom value stream data', () => {
      const response = {};
      const expectedUrl = '/gitlab/-/subscriptions/validate_payment_method';
      mock.onPost(expectedUrl).reply(HTTP_STATUS_OK, response);

      return Api.validatePaymentMethod('id', 'user_id').then((res) => {
        expect(res.data).toEqual(response);
        expect(res.config.url).toEqual(expectedUrl);
      });
    });
  });
});
